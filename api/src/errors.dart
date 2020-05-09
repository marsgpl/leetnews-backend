Map<String, int> ERROR_CODES = {
    'METHOD_NOT_ALLOWED_FOR_ROUTE': 1,
    'ROUTE_NOT_FOUND': 2,
    'INTERNAL_ERROR': 3,
};

Map<String, String> ERROR_REASONS = {
    'METHOD_NOT_ALLOWED_FOR_ROUTE': 'HTTP Method "%method" is not allowed for route "%route"',
    'ROUTE_NOT_FOUND': 'Route "%route" does not exist',
    'INTERNAL_ERROR': 'Internal server error',
};
