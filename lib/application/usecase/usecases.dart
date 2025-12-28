// Barrel file for application usecases
// All domains now follow the same pattern: lib/application/{domain}/usecase/

// Account usecases
export '../account/usecase/create_account_usecase.dart';

// Auth usecases (authentication domain)
export '../auth/usecase/login_usecase.dart';

// Auth - API Key usecases (API Keys são uma forma de autenticação)
export '../auth/api_key/usecase/create_api_key_usecase.dart';
export '../auth/api_key/usecase/generate_api_key_usecase.dart';
export '../auth/api_key/usecase/list_api_keys_usecase.dart';
export '../auth/api_key/usecase/revoke_api_key_usecase.dart';

// Artifact usecases
export '../artifact/usecase/check_artifact_exists_usecase.dart';
export '../artifact/usecase/create_artifact_usecase.dart';
export '../artifact/usecase/download_artifact_tarball_usecase.dart';
export '../artifact/usecase/download_artifact_usecase.dart';
export '../artifact/usecase/get_artifact_by_id_usecase.dart';
export '../artifact/usecase/get_artifact_download_stream_usecase.dart';
export '../artifact/usecase/get_artifact_usecase.dart';
export '../artifact/usecase/upload_artifact_usecase.dart';

// Compliance usecases
export '../compliance/usecase/register_compliance_artifact_usecase.dart';

// Health usecases
export '../health/usecase/get_server_health_usecase.dart';

// Package usecases
export '../package/usecase/get_package_metadata_usecase.dart';
export '../package/usecase/proxy_package_metadata_usecase.dart';
export '../package/usecase/proxy_package_tarball_usecase.dart';
