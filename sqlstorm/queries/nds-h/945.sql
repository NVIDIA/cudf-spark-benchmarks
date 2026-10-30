WITH supplier_summary AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        SUM(ps.ps_availqty) AS total_availqty,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY
        s.s_suppkey, s.s_name, s.s_acctbal
),

order_summary AS (
    SELECT
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        COUNT(l.l_orderkey) AS total_lineitems
    FROM
        orders o
    JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE
        o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31' 
    GROUP BY
        o.o_orderkey, o.o_custkey
),

nation_supplier AS (
    SELECT
        n.n_nationkey,
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM
        nation n
    LEFT JOIN
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY
        n.n_nationkey, n.n_name
)

SELECT 
    ns.n_name,
    ns.supplier_count,
    COALESCE(ss.total_availqty, 0) AS total_availqty,
    COALESCE(ss.total_supplycost, 0) AS total_supplycost,
    COALESCE(os.total_order_value, 0) AS total_order_value,
    COALESCE(os.total_lineitems, 0) AS total_lineitems
FROM 
    nation_supplier ns
LEFT JOIN 
    supplier_summary ss ON ns.n_nationkey = ss.s_suppkey
LEFT JOIN 
    order_summary os ON ns.n_nationkey = os.o_custkey
WHERE 
    (ss.total_supplycost IS NULL OR ss.total_supplycost > 10000) 
    AND ns.supplier_count > 5
ORDER BY 
    ns.n_name ASC, total_order_value DESC
LIMIT 50;