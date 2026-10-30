
WITH RankedSuppliers AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM
        supplier s
    WHERE
        s.s_acctbal IS NOT NULL
),
HighValueCustomers AS (
    SELECT
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        c.c_nationkey
    FROM
        customer c
    WHERE
        c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2)
),
LargeOrders AS (
    SELECT
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        COUNT(l.l_orderkey) AS line_count
    FROM
        orders o
    JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY
        o.o_orderkey
    HAVING
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
),
NationStats AS (
    SELECT
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        SUM(s.s_acctbal) AS total_acctbal
    FROM
        nation n
    LEFT JOIN
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY
        n.n_name
),
FinalReport AS (
    SELECT
        ps.ps_partkey,
        p.p_name,
        ns.n_name AS nation_name,
        SUM(ps.ps_availqty) AS total_avail_qty,
        MAX(l.total_order_value) AS max_order_value,
        COALESCE(RANKED.rn, 0) AS supplier_rank
    FROM
        partsupp ps
    JOIN
        part p ON ps.ps_partkey = p.p_partkey
    LEFT JOIN
        RankedSuppliers RANKED ON ps.ps_suppkey = RANKED.s_suppkey
    LEFT JOIN
        LargeOrders l ON l.o_orderkey = (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey IN (SELECT c.c_custkey FROM HighValueCustomers c) LIMIT 1)
    JOIN
        NationStats ns ON ns.supplier_count > 5
    GROUP BY
        ps.ps_partkey, p.p_name, ns.n_name, RANKED.rn
)
SELECT
    f.p_name,
    f.nation_name,
    f.total_avail_qty,
    f.max_order_value,
    CASE 
        WHEN f.supplier_rank IS NULL THEN 'No Supplier'
        ELSE CAST(f.supplier_rank AS STRING)
    END AS supplier_rank_result,
    CASE 
        WHEN f.max_order_value IS NULL THEN 'Zero Value'
        ELSE CAST(f.max_order_value AS STRING)
    END AS order_value_result
FROM
    FinalReport f
WHERE
    f.total_avail_qty > 50
ORDER BY
    f.total_avail_qty DESC, f.max_order_value DESC
LIMIT 15 OFFSET 10;
