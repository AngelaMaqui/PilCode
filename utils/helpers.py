import csv
import io
from flask import Response


def csv_response(filename, headers, rows):
    output = io.StringIO()
    writer = csv.writer(output)
    writer.writerow(headers)
    for row in rows:
        if isinstance(row, dict):
            writer.writerow([row.get(h, '') for h in headers])
        else:
            writer.writerow(row)
    output.seek(0)
    return Response(
        output.getvalue(),
        mimetype='text/csv',
        headers={'Content-disposition': f'attachment; filename={filename}'}
    )


ROLE_NAMES = {1: 'Administrador', 2: 'Gerente', 3: 'Distribuidor'}
