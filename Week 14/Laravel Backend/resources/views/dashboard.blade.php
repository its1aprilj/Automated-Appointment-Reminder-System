<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Appointment Reminder Dashboard</title>

    <style>
        :root {
            --primary: #5267c5;
            --background: #f4f6fb;
            --text: #202944;
            --muted: #718096;
            --border: #e5e9f2;
            --white: #ffffff;
        }

        * {
            box-sizing: border-box;
        }

        body {
            margin: 0;
            background: var(--background);
            color: var(--text);
            font-family: "Segoe UI", Arial, sans-serif;
        }

        header {
            background: var(--white);
            border-bottom: 1px solid var(--border);
            padding: 20px 5%;
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 16px;
            flex-wrap: wrap;
        }

        .brand {
            display: flex;
            align-items: center;
            gap: 12px;
        }

        .brand-icon {
            background: var(--primary);
            color: white;
            width: 44px;
            height: 44px;
            border-radius: 12px;
            display: grid;
            place-items: center;
            font-size: 23px;
        }

        h1,
        h2,
        p {
            margin-top: 0;
        }

        h1 {
            font-size: 21px;
            margin-bottom: 4px;
        }

        .subtitle,
        .muted {
            color: var(--muted);
            font-size: 13px;
        }

        .demo {
            padding: 9px 13px;
            border-radius: 20px;
            background: #fff4dc;
            color: #8a5b00;
            font-size: 12px;
            font-weight: 700;
        }

        main {
            max-width: 1500px;
            margin: auto;
            padding: 30px 5%;
        }

        .page-heading {
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 15px;
            flex-wrap: wrap;
            margin-bottom: 24px;
        }

        .page-heading h2 {
            margin-bottom: 7px;
            font-size: 27px;
        }

        .refresh {
            text-decoration: none;
            background: var(--primary);
            color: white;
            padding: 11px 17px;
            border-radius: 9px;
            font-size: 13px;
            font-weight: 600;
        }

        .stats {
            display: grid;
            grid-template-columns: repeat(4, minmax(0, 1fr));
            gap: 16px;
            margin-bottom: 28px;
        }

        .stat,
        .panel {
            background: var(--white);
            border: 1px solid var(--border);
            border-radius: 14px;
            box-shadow: 0 4px 15px rgba(33, 48, 90, .035);
        }

        .stat {
            padding: 20px;
        }

        .stat-label {
            font-size: 13px;
            color: var(--muted);
            margin-bottom: 12px;
        }

        .stat-value {
            font-size: 30px;
            font-weight: 750;
        }

        .stat-note {
            font-size: 12px;
            color: var(--muted);
            margin-top: 7px;
        }

        .panel {
            margin-bottom: 25px;
            overflow: hidden;
        }

        .panel-heading {
            padding: 20px 22px;
            border-bottom: 1px solid var(--border);
        }

        .panel-heading h2 {
            font-size: 18px;
            margin-bottom: 5px;
        }

        .table-wrap {
            overflow-x: auto;
        }

        table {
            width: 100%;
            border-collapse: collapse;
            min-width: 900px;
        }

        th,
        td {
            padding: 15px 18px;
            text-align: left;
            border-bottom: 1px solid var(--border);
            font-size: 13px;
        }

        th {
            color: var(--muted);
            background: #fafbfe;
            font-size: 11px;
            text-transform: uppercase;
            letter-spacing: .5px;
        }

        tbody tr:last-child td {
            border-bottom: none;
        }

        .name {
            font-weight: 650;
        }

        .status {
            display: inline-block;
            padding: 6px 10px;
            border-radius: 20px;
            font-size: 11px;
            font-weight: 700;
            white-space: nowrap;
        }

        .scheduled {
            background: #e9efff;
            color: #3455b5;
        }

        .delivered {
            background: #e0f7e9;
            color: #177245;
        }

        .retrying {
            background: #fff1d9;
            color: #9a5b00;
        }

        .manual_review {
            background: #ffe6e6;
            color: #b42323;
        }

        .expired {
            background: #eceef2;
            color: #5f6673;
        }

        .cancelled {
            background: #e7eaf0;
            color: #505968;
        }

        .empty {
            text-align: center;
            padding: 35px 20px;
            color: var(--muted);
        }

        .logs {
            padding: 5px 22px;
        }

        .log-item {
            display: grid;
            grid-template-columns: 115px minmax(0, 1fr);
            gap: 15px;
            padding: 17px 0;
            border-bottom: 1px solid var(--border);
        }

        .log-item:last-child {
            border-bottom: none;
        }

        .log-time {
            color: var(--muted);
            font-size: 12px;
        }

        .log-event {
            font-weight: 650;
            font-size: 13px;
            margin-bottom: 5px;
            overflow-wrap: anywhere;
        }

        .log-message {
            font-size: 13px;
            color: #606c82;
            overflow-wrap: anywhere;
        }

        footer {
            color: var(--muted);
            text-align: center;
            font-size: 12px;
            padding: 15px 10px 30px;
        }

        @media (max-width: 950px) {
            .stats {
                grid-template-columns: repeat(2, minmax(0, 1fr));
            }
        }

        @media (max-width: 520px) {
            main {
                padding: 22px 4%;
            }

            .stats {
                grid-template-columns: 1fr 1fr;
                gap: 10px;
            }

            .stat {
                padding: 15px;
            }

            .stat-value {
                font-size: 25px;
            }

            .log-item {
                grid-template-columns: 1fr;
                gap: 6px;
            }

            .page-heading h2 {
                font-size: 23px;
            }
        }
    </style>
</head>

<body>
    <header>
        <div class="brand">
            <div class="brand-icon">◷</div>
            <div>
                <h1>Appointment Reminder System</h1>
                <div class="subtitle">Week 13 · Automation Foundation</div>
            </div>
        </div>

        <div class="demo">DEMO MODE · SIMULATED DELIVERY</div>
    </header>

    <main>
        <div class="page-heading">
            <div>
                <h2>Dashboard Overview</h2>
                <p class="subtitle">Monitor appointments, reminder outcomes, and automation activity.</p>
            </div>

            <a class="refresh" href="{{ route('dashboard') }}">↻ Refresh Dashboard</a>
        </div>

        <section class="stats">
            <div class="stat">
                <div class="stat-label">Total Appointments</div>
                <div class="stat-value">{{ $stats['total'] }}</div>
                <div class="stat-note">All saved records</div>
            </div>

            <div class="stat">
                <div class="stat-label">Scheduled</div>
                <div class="stat-value">{{ $stats['scheduled'] }}</div>
                <div class="stat-note">Awaiting processing</div>
            </div>

            <div class="stat">
                <div class="stat-label">Delivered</div>
                <div class="stat-value">{{ $stats['delivered'] }}</div>
                <div class="stat-note">Simulated successful outcomes</div>
            </div>

            <div class="stat">
                <div class="stat-label">Retrying</div>
                <div class="stat-value">{{ $stats['retrying'] }}</div>
                <div class="stat-note">Temporary delivery failures</div>
            </div>

            <div class="stat">
                <div class="stat-label">Manual Review</div>
                <div class="stat-value">{{ $stats['manual_review'] }}</div>
                <div class="stat-note">Needs human action</div>
            </div>

            <div class="stat">
                <div class="stat-label">Expired</div>
                <div class="stat-value">{{ $stats['expired'] }}</div>
                <div class="stat-note">Appointments closed</div>
            </div>

            <div class="stat">
                <div class="stat-label">Cancelled</div>
                <div class="stat-value">{{ $stats['cancelled'] }}</div>
                <div class="stat-note">Reminders disabled</div>
            </div>

            <div class="stat">
                <div class="stat-label">Automation</div>
                <div class="stat-value" style="font-size:20px;color:#177245">Configured</div>
                <div class="stat-note">Laravel scheduler registered</div>
            </div>
        </section>

        <section class="panel">
            <div class="panel-heading">
                <h2>Appointment Records</h2>
                <div class="subtitle">Current records stored in the Laravel database</div>
            </div>

            <div class="table-wrap">
                <table>
                    <thead>
                        <tr>
                            <th>ID / Client</th>
                            <th>Service</th>
                            <th>Appointment Date</th>
                            <th>Status</th>
                            <th>Attempts</th>
                            <th>Next Attempt</th>
                        </tr>
                    </thead>

                    <tbody>
                        @forelse ($appointments as $appointment)
                            <tr>
                                <td>
                                    <div class="name">#{{ $appointment->id }} · {{ $appointment->name }}</div>
                                    <div class="muted">{{ $appointment->destination }}</div>
                                </td>

                                <td>{{ $appointment->service }}</td>

                                <td>
                                    {{ $appointment->appointment_at?->format('M d, Y h:i A') ?? '—' }}
                                </td>

                                <td>
                                    <span class="status {{ $appointment->status }}">
                                        {{ str_replace('_', ' ', ucfirst($appointment->status)) }}
                                    </span>
                                </td>

                                <td>{{ $appointment->attempts }} / {{ $appointment->max_attempts }}</td>

                                <td>
                                    {{ $appointment->next_attempt_at?->format('M d, Y h:i A') ?? '—' }}
                                </td>
                            </tr>
                        @empty
                            <tr>
                                <td colspan="6" class="empty">
                                    No appointments found. Create a test appointment using the API to get started.
                                </td>
                            </tr>
                        @endforelse
                    </tbody>
                </table>
            </div>
        </section>

        <section class="panel">
            <div class="panel-heading">
                <h2>Recent Automation Activity</h2>
                <div class="subtitle">Latest saved events from the reminder logs</div>
            </div>

            <div class="logs">
                @forelse ($logs as $log)
                    <div class="log-item">
                        <div class="log-time">
                            {{ $log->created_at?->format('M d, h:i A') ?? '—' }}
                        </div>

                        <div>
                            <div class="log-event">
                                {{ strtoupper(str_replace('_', ' ', $log->event)) }}
                                · Appointment #{{ $log->appointment_id }}
                            </div>

                            <div class="log-message">{{ $log->message }}</div>
                        </div>
                    </div>
                @empty
                    <div class="empty">No activity logs have been recorded yet.</div>
                @endforelse
            </div>
        </section>
    </main>

    <footer>
        Appointment Reminder System · Week 13 Prototype · Laravel
        <br>
        Delivery events are simulated; no external email or SMS provider is connected.
    </footer>
</body>

</html>