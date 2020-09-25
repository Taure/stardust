-define(DEBUG(M), logger:debug(M)).
-define(DEBUG(M, Meta), logger:debug(M, Meta)).
-define(INFO(M), logger:info(M)).
-define(INFO(M,Meta), logger:info(M, Meta)).
-define(WARNING(M), logger:warning(M)).
-define(WARNING(M,Meta), logger:warning(M, Meta)).
-define(ERROR(M), logger:error(M)).
-define(ERROR(M,Meta), logger:error(M, Meta)).
-define(UNEXPECTED(Type, Content),
        ?WARNING("Unexpected ~p: ~p", [Type, Content]))).