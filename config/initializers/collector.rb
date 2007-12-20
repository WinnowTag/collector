# winnow_collect_log_file 
# based on the comment above regarding RAILS_ROOT being set incorrect I'll use 
# relative paths
logger_suffix = RAILS_ENV == 'test' ? 'test' : ""
WINNOW_COLLECT_LOG = File.join(RAILS_ROOT, 'log', "winnow_collect.log#{logger_suffix}")
