WITH ranked_orders AS (
    SELECT
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderpriority,
        c.c_name,
        c.c_acctbal,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS price_rank
    FROM
        orders o
    JOIN
        customer c ON o.o_custkey = c.c_custkey
),
supplier_summary AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY
        s.s_suppkey, s.s_name
),
high_value_orders AS (
    SELECT
        ro.o_orderkey,
        ro.o_totalprice,
        ro.o_orderdate,
        ro.c_name,
        ro.o_orderstatus
    FROM
        ranked_orders ro
    WHERE
        ro.price_rank <= 10
),
final_report AS (
    SELECT
        hvo.o_orderkey,
        hvo.o_totalprice,
        hvo.o_orderdate,
        hvo.c_name,
        COUNT(DISTINCT ps.ps_partkey) AS unique_parts,
        AVG(ss.avg_supply_cost) AS avg_supplier_cost
    FROM
        high_value_orders hvo
    LEFT JOIN
        lineitem l ON hvo.o_orderkey = l.l_orderkey
    LEFT JOIN
        partsupp ps ON l.l_partkey = ps.ps_partkey
    LEFT JOIN
        supplier_summary ss ON ps.ps_suppkey = ss.s_suppkey
    GROUP BY
        hvo.o_orderkey, hvo.o_totalprice, hvo.o_orderdate, hvo.c_name
)
SELECT
    fr.o_orderkey,
    fr.o_totalprice,
    fr.o_orderdate,
    fr.c_name,
    fr.unique_parts,
    fr.avg_supplier_cost
FROM
    final_report fr
ORDER BY
    fr.o_totalprice DESC
LIMIT 50;
