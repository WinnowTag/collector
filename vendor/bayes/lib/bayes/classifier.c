// Copyright (c) 2007 The Kaphan Foundation
//
// Possession of a copy of this file grants no permission or license
// to use, modify, or create derivate works.
//
// Please contact info@peerworks.org for further information.

// This is C implementation of the Peerworks Bayesian Classifier.
// This C code is very much dependent on Ruby.
//
// The code also contains the Ruby hooks into the classifier.
//
// For more thorough documentation see classifier.rb
//

#include <math.h>

#define max(A,B)	( (A) > (B) ? (A):(B))
#define TINY_VAL_D 1e-200
#define DEBUG 0

// Defines the probability assigned to unknown words.
//
// This was inspired by the SpamBayes option of the same name.
#define UNKNOWN_WORD_PROB 0.5

// Defines the weighting to give to the unknown word probability.
//
// This was inspired by the SpamBayes option of the same name.
#define UNKNOWN_WORD_STRENGTH 0.45
#define S_TIMES_X (UNKNOWN_WORD_STRENGTH * UNKNOWN_WORD_PROB)

// The minimum probability strength to use when building a probability cache for a Pool. 
// The probabilities that are less that min_prob_strength distance from 0.5 are ignored. 
// 
// This defaults to 0.1 
// 
// This was added as part of the distance thresholding change described in ticket 257. 
#define MIN_PROB_STRENGTH 0.1 

// The maximum number of discriminators to use when building a probability cache for a Pool. 
// The top max_discriminators probabilities ordered by distances from 0.5 are used for each pool. 
// 
// The default is 150. 
// 
// This was added as part of the distance thresholding change described in ticket 257. 
#define MAX_DISCRIMINATORS 150

// This is the ratio of clues in an items to use as the maximum clues.
//
// We get the max clues value by taking
//   
//   max(MAX_DISCRIMINATORS, MAX_CLUES_RATIO * item_length)
//
// This prevent large items from not having enough clues to have a balanced
// probability calculation which was creating tag magnets.
// 
#define MAX_CLUES_RATIO 0.5

/* Store probability options in a struct so they can be passed around
 * between C functions without needing to access the Ruby environment.
 */
struct probability_options {
  double bias;
  int include_evidence;
};
      
void options_from_ruby(VALUE rb_prob_opts, struct probability_options *opts) {
  opts->bias = NUM2DBL(rb_iv_get(rb_prob_opts, "@bias"));
  opts->include_evidence = (rb_iv_get(rb_prob_opts, "@include_evidence") == Qtrue);
}

/*==================================================================
 * Struct and functions for clues 
 */

struct clue {
  double dist;
  double prob;
  VALUE token;
  struct clue *next;
};

void free_clues(struct clue * clues) {
  struct clue * current = clues;
  struct clue * next;

  while (current != 0) {
    next = current->next;
    free(current);
    current = next;
  }
}

struct clue * append_clue(double dist, double prob, VALUE token, struct clue *root, const int max_clues){
  struct clue * new_clue = 0;
  int num_clues = 1;

  /* If there is a root clue iterate through the clues until we find
   * either the end or clue where dist is less than current->dist but
   * greater than current->next->dist, the new clue goes there. This
   * keeps clues sorted by the greatest distance from 0.5.
   */
  if (root) {
    struct clue *current = root;          

    while (current->next != 0 && current->next->dist > dist) {
      current = current->next;
      num_clues++;
    }
  
    /* If we haven't gone past the max_clues 
     * then insert the clue after current.
     * 
     */
    if (num_clues < max_clues) {
      new_clue = malloc( sizeof(struct clue) );
      new_clue->next = current->next;
      current->next = new_clue;
    }
  } else {
    root = new_clue = malloc( sizeof(struct clue) );
    new_clue->next = 0;          
  }

  if (new_clue) {
    new_clue->dist = dist;
    new_clue->prob = prob;
    new_clue->token = token;
  
    /* Maintain the length of the list to be no greater than max_clues. 
     * Do this from the new_clue position so we don't need to go back
     * to the beginning of the clue list.
     *
     * So iterate up to the clue before max_clues then free from the
     * max_clue onwards.
     */
    struct clue *current = new_clue;
    while (current->next != 0 && num_clues < max_clues - 1) {
      current = current->next;
      num_clues++;
    }
  
    free_clues(current->next);
    current->next = 0;
  }

  return root;    
}

void print_clues(struct clue *current) {
  while (current) {
    printf("%f, %f, %i\\n", current->dist, current->prob, current->token);
    current = current->next;
  }
}     

VALUE clues2array(struct clue *clues) {
  struct clue * current = clues;
  VALUE ary = rb_ary_new();

  while (current != 0) {
    VALUE clue = rb_ary_new2(2);
    rb_ary_push(clue, rb_float_new(current->prob));
    rb_ary_push(clue, current->token);
    rb_ary_push(ary, clue);
    current = current->next;
  }

  return ary;
}    

/*====================================================================
 * Functions to help with probability calculations.
 */

/* Just sums together all the elements of a double array.
 */
static inline double
sum(double *arr, int size) {
  int i;
  double sum = 0;

  for (i = 0; i < size; i++) {
    sum += arr[i];
  }

  return sum;
}

/* Calculates an average of an array of doubles.
 * 
 * Values less than or equal to zero are filtered out of the average.
 */
static inline double
average(double *arr, int size) {             
  double sum = 0;
  int i, denominator = 0;
  
  for (i = 0; i < size; i++) {
    if (arr[i] > 0) {
      sum += arr[i];
      denominator++;
    }
  }
  
  if (denominator == 0) {
    return 0;
  } else {
    return sum / denominator;            
  }
}

/* N provides a measure of confidence in a probability for a token.
 * It is used in the Bayesian Adjustment.  For more info on what is
 * does and how we got to the current calculation for it see the 
 * class level comments.
 *
 * With the move to arbitrary pools, n is calculated slightly differently
 * but with the same aim and results. It now takes an array of token counts
 * and an array total counts for number of pools. The ith element in the
 * token count array correponds to the ith element in the total count array.
 *
 * N is computed by summing each token count multiplied by the size of all the 
 * other pools, divided by the size of the pool the token count came from.
 */
static inline double
compute_n(double *fg_token_counts, double *fg_total_counts, int fg_size,
          double *bg_token_counts, double *bg_total_counts, int bg_size) {
  int i;
  double fg_ns[fg_size];
  double bg_ns[bg_size];
  double fg_total_sum = sum(fg_total_counts, fg_size);
  double bg_total_sum = sum(bg_total_counts, bg_size);
  
  if (fg_total_sum <= 0) fg_total_sum = 1;
  if (bg_total_sum <= 0) bg_total_sum = 1;  

  // This formula is more cleary expressed as:
  //  
  //  n +=  token count * sum of total counts for all opposite pools 
  //                      -------------------------------------------
  //                             the total_count for this
  //
  for (i = 0; i < fg_size; i++) {
    if (fg_total_counts[i] > 0) {
      fg_ns[i] = (fg_token_counts[i] * bg_total_sum  / fg_total_counts[i]);
    } else {
      fg_ns[i] = 0;
    }
  
  }

  for (i = 0; i < bg_size; i++) {
    if (bg_token_counts[i] > 0) {
      bg_ns[i] = (bg_token_counts[i] * fg_total_sum  / bg_total_counts[i]);
    } else {
      bg_ns[i] = 0;
    }
  }
   
  return average(fg_ns, fg_size) + average(bg_ns, bg_size);
}

static inline int
collect_counts(VALUE token, VALUE pools, int size, double * token_counts, double * total_counts, double bias) {
  int non_zero = 0;
  int i;
  for (i = 0; i < size; i++) {
    VALUE pool = RARRAY(pools)->ptr[i];
    VALUE tokens = rb_iv_get(pool, "@tokens");
    token_counts[i] = NUM2DBL(rb_hash_aref(tokens, token));
    total_counts[i] = NUM2DBL(rb_iv_get(pool, "@token_count")) * bias;
    
    if (token_counts[i] > 0) {
      non_zero++;
    }
  }  
  
  return non_zero;
}

/** Computes the ratio for a token in each pool.
 *
 *  Parameters:
 *    * ratios - A double array large enough to hold a ratio for each pool.
 *    * token_counts - A double array containing the token counts for each pool.
 *    * total_counts - A double array containing the total counts for each pool.
 *    * size - The number of counts to process
 *
 */
static inline void
compute_ratios(double * ratios, double * token_counts, double * total_counts, int size) {
  int i;
  for (i = 0; i < size; i++) {
    // Prevent divide by 0
    if (total_counts[i] == 0) {
      ratios[i] = 0;
    } else {
      // Calculate the ratio for the token in this pool
      ratios[i] = token_counts[i] / total_counts[i];
    }
  }
}

/* Gets the probability that a token occurs in a pool.
 * 
 *  * token - The token to get the probability for.
 *  * fg_pools - A Ruby Array of Bayes::Pool objects to use as the foreground.
 *  * bg_pools - A Ruby Array of Bayes::Pool objects to use as additional backgrounds.
 *  * corpus - A Bayes::Pool object that is used as the base background.  The token counts
 *             each of the foregrounds and backgrounds will be subtracted from the counts
 *             within corpus to arrive at a pool that behaves as everything but the specified
 *             foreground and background pools.
 *  * opts - The probablity options to use.
 */
static double
_probability(VALUE token, VALUE fg_pools, VALUE bg_pools, struct probability_options opts) {
  double probability = UNKNOWN_WORD_PROB;
  int num_fg_pools = RARRAY(fg_pools)->len;
  int num_bg_pools = RARRAY(bg_pools)->len;
  int total_pools = num_fg_pools + num_bg_pools;

  // Collect all the token and total counts into arrays
  double token_counts[total_pools];         
  double total_counts[total_pools];
  // These are just pointers into the main arrays for the position 
  // of the background pools to help with readability.
  double * bg_token_counts = &token_counts[num_bg_pools];
  double * bg_total_counts = &total_counts[num_bg_pools];

  int non_zero_fg = collect_counts(token, fg_pools, num_fg_pools, token_counts, total_counts, 1 / opts.bias);
  int non_zero_bg = collect_counts(token, bg_pools, num_bg_pools, bg_token_counts, bg_total_counts, opts.bias);
  
  // Only proceed if there were some non-zero token counts
  if (non_zero_fg > 0 || non_zero_bg > 0) {
    // Collect all the foreground and background ratios into an array of doubles
    double fg_ratios[num_fg_pools];
    double bg_ratios[num_bg_pools];
    compute_ratios(fg_ratios, token_counts, total_counts, num_fg_pools);
    compute_ratios(bg_ratios, bg_token_counts, bg_total_counts, num_bg_pools);
             
    // Now combine the ratio arrays using averages
    double fg_ratio = average(fg_ratios, num_fg_pools);
    double bg_ratio = average(bg_ratios, num_bg_pools);

    probability = fg_ratio / (fg_ratio + bg_ratio);
                    
    // See the class level comments for a discussion on 'n'
    const double n = compute_n(token_counts, total_counts, num_fg_pools,
                               bg_token_counts, bg_total_counts, num_bg_pools);

    if (DEBUG){
      //printf("token = %s\n", (RSTRING(token)->ptr));
      printf("fg_ratio = %f\n", fg_ratio);
      printf("bg_ratio = %f\n", bg_ratio);
      printf("pre_adjustment_prob = %f\n", probability);
      printf("n = %f\n", n);
    }

    /* Do the Bayesian adjustment found in SpamBayes.
     *
     * See also:
     * SpamBayes code
     *  (http://spambayes.cvs.sourceforge.net/spambayes/spambayes/spambayes/classifier.py?view=markup)
     * Essay by Gary Robinson
     *  (http://radio.weblogs.com/0101454/stories/2002/09/16/spamDetection.html)
     */
    probability = (S_TIMES_X + n * probability) / (UNKNOWN_WORD_STRENGTH + n);

    // Make sure probability is not 0
    if (probability == 0.0) {
      rb_raise(rb_eStandardError, "Probability became 0!");
    }
  }
  
  if (DEBUG) {
    printf("P = %f\n\n", probability);
  }
  
  return probability;
}

/* Get the probabilities that each of the tokens appears in the given pool.
 *
 *  * fg_pools - A Array of Bayes::Pools to use as the foreground.
 *  * bg_pools - A Array of Bayes::Pools to use as the background.
 *  * corpus   - A Bayes::Pool that provides the generic background corpus.
 *  * tokens - An array of tokens.
 *  * opts - A probability options struct.
 *
 *  * Returns an array of probability, token pairs in the form [prob, token]
 *    sorted by increasing probability strength, i.e. distance from 0.5. prob
 *    is the probability that the token is in in the pool identified by pool_name.
 *    No more than Bayes.max_discriminator items are returned.  Tokens with prob
 *    less than Bayes.min_prob_strength distance from 0.5 are not returned.
 */
static struct clue *
_get_clues(VALUE tokens, VALUE fg_pools, VALUE bg_pools, VALUE cache, struct probability_options opts) {
  Check_Type(tokens, T_ARRAY);
  Check_Type(fg_pools, T_ARRAY);
  Check_Type(bg_pools, T_ARRAY);
  Check_Type(cache, T_HASH);
  struct clue *clues = 0;        
  int token_array_length = RARRAY(tokens)->len;
  int max_clues = max(MAX_DISCRIMINATORS, MAX_CLUES_RATIO * token_array_length);
  VALUE* token_array = RARRAY(tokens)->ptr;

  int i;
  for (i = 0; i < token_array_length; i++) {
    double prob;
    VALUE probability = rb_hash_aref(cache, token_array[i]);
    if (probability == Qnil) {
      prob = _probability(token_array[i], fg_pools, bg_pools, opts);
      rb_hash_aset(cache, token_array[i], rb_float_new(prob));
    } else {
      prob = NUM2DBL(probability);
    }
  
    double dist = fabs(prob - 0.5);
  
    // Only add it to the list of clues if it is above the min_prob_strength threshold
    if (dist >= MIN_PROB_STRENGTH) {
      clues = append_clue(dist, prob, token_array[i], clues, max_clues);
    }
  }

  return clues;
}

/* Returns prob(chisq >= x2, with v degrees of freedom)
 *
 * Algorithm taken from http://spambayes.cvs.sourceforge.net/spambayes/spambayes/spambayes/chi2.py?view=markup
 */
double chi2Q(double x2, int v) {
  int i;
  int max_i = v / 2;
  double m = x2 / 2;
  double sum, term;
  sum = term = exp(-m);

  for (i = 1; i <= max_i; i++) {
    term *= m / i;
    sum += term;
  }

  if (sum > 1.0) {
    sum = 1.0;
  }

  return sum;
}

/* Computes the probability that the tokens belong to the pool identified by pool_name.
 *
 * This method is based on the chi2_spamprob method in SpamBayes. To make it easier to compare
 * this method with the original method, the ham and spam variable names have been maitained.
 * In the context of this classifier, spam is belonging to the pool identified by pool_name and
 * ham is belonging to the other pools.
 *
 * This method will follow the algorithm pretty closely, for detail see
 * http://spambayes.cvs.sourceforge.net/spambayes/spambayes/spambayes/classifier.py?revision=1.31&view=markup
 * Major deviations will be documented here.
 */
static VALUE
chi2_prob(int argc, VALUE *argv, VALUE self) {
  if (argc != 5) {
    rb_raise(rb_eArgError, "chi2_prob expects 5 arguments but got %i", argc);
  }

  int num_clues, sExp, hExp;
  double h, s, prob;
  struct probability_options opts;

  VALUE tokens = argv[0];
  VALUE fg_pools = argv[1];
  VALUE bg_pools = argv[2];
  VALUE cache = argv[3];
  options_from_ruby(argv[4], &opts);
        
  h = s = 1.0;
  num_clues = sExp = hExp = 0;

  struct clue *clues = _get_clues(tokens, fg_pools, bg_pools, cache, opts);
  struct clue *current = clues;                

  while (current != 0) {
    num_clues++;
    s *= (1.0 - current->prob);
    h *= current->prob;
    current = current->next;
  
    // correct for potential underflows
    if (s < TINY_VAL_D) {
      int e = 0;
      s = frexp(s, &e);
      sExp += e;
    }
  
    if (h < TINY_VAL_D) {
      int e = 0;
      h = frexp(h, &e);
      hExp += e;
    }
  }

  s = log(s) + sExp * M_LN2;
  h = log(h) + hExp * M_LN2;

  if (num_clues > 0) {
    int n2 = num_clues * 2;
    s = 1.0 - chi2Q(-2.0 * s, n2);
    h = 1.0 - chi2Q(-2.0 * h, n2);
    prob = (s - h + 1.0) / 2.0;
  } else {
    prob = 0.5;
  }

  if (opts.include_evidence) {
     VALUE ary = rb_ary_new();
     rb_ary_push(ary, rb_float_new(prob));
     rb_ary_push(ary, clues2array(clues));
     free_clues(clues);
     return ary;
  } else {
    free_clues(clues);
    return rb_float_new(prob);
  }
}

// Ruby method hook into the probability C function - this aids testing only
static VALUE
probability(int argc, VALUE *argv, VALUE self) {
  if (argc != 4) {
    rb_raise(rb_eArgError, "probability expects 4 arguments (token,foreground_pools,background_pools,options) but got %d arguments.", argc);
  } else {         
    struct probability_options opts;
    options_from_ruby(argv[3], &opts);
    return rb_float_new(_probability(argv[0], argv[1], argv[2], opts));
  }
}

// Ruby method hook into the get_clues C function - this aids testing only
static VALUE
get_clues(int argc, VALUE *argv, VALUE self) {
  if (argc != 5) {
    rb_raise(rb_eArgError, "get_clues expects 5 arguments but got %d", argc);
  } else {
    struct probability_options opts;
    options_from_ruby(argv[4], &opts);
    struct clue *clues = _get_clues(argv[0], argv[1], argv[2], argv[3], opts);
    return clues2array(clues);
  }      
}