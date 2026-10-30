
WITH  order_summary AS (
    SELECT
        o.o_orderkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_partkey) AS unique_parts,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
    FROM
        orders o
    JOIN
        customer c ON o.o_custkey = c.c_custkey
    JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY
        o.o_orderkey, c.c_name, c.c_nationkey
),
expanded_parts AS (
    SELECT
        p.p_partkey,
        p.p_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        (ps.ps_supplycost * ps.ps_availqty) AS supply_value
    FROM
        part p
    LEFT JOIN
        partsupp ps ON p.p_partkey = ps.ps_partkey
),
nations_summary AS (
    SELECT
        n.n_nationkey,
        SUM(s.s_acctbal) AS total_balance
    FROM
        nation n
    JOIN
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY
        n.n_nationkey
)
SELECT
    c.c_name,
    os.total_revenue,
    os.unique_parts,
    np.total_balance,
    ep.p_name,
    ep.supply_value,
    CASE 
        WHEN ep.supply_value IS NULL THEN 'No Supply Information'
        ELSE 'Supply Available'
    END AS supply_status
FROM
    order_summary os
JOIN
    customer c ON os.c_name = c.c_name
LEFT JOIN
    nations_summary np ON c.c_nationkey = np.n_nationkey
LEFT JOIN
    expanded_parts ep ON os.unique_parts = ep.p_partkey
WHERE
    os.rank <= 5
    AND np.total_balance IS NOT NULL
ORDER BY
    os.total_revenue DESC, np.total_balance DESC;
