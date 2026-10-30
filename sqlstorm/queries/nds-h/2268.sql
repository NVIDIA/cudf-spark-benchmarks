WITH supplier_summary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    LEFT JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        s.s_acctbal > 0 OR o.o_orderstatus = 'F'
    GROUP BY 
        s.s_suppkey, s.s_name
),
customer_rank AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY c.c_acctbal DESC) AS rank
    FROM 
        customer c
    WHERE 
        c.c_acctbal IS NOT NULL
),
lineitem_summary AS (
    SELECT 
        l.l_orderkey,
        COUNT(l.l_linenumber) AS items_count,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
        MAX(l.l_shipdate) AS max_shipdate
    FROM 
        lineitem l
    WHERE 
        l.l_returnflag = 'N'
    GROUP BY 
        l.l_orderkey
)
SELECT 
    ns.n_name,
    ss.s_name,
    cs.c_name,
    cs.rank,
    ls.items_count,
    ls.total_price,
    ls.max_shipdate,
    COALESCE(ss.total_available, 0) AS total_available,
    COALESCE(ss.total_cost, 0) AS total_cost
FROM 
    nation ns
JOIN 
    supplier_summary ss ON ns.n_nationkey = ss.s_suppkey
JOIN 
    customer_rank cs ON ns.n_nationkey = cs.c_custkey
JOIN 
    lineitem_summary ls ON ss.s_suppkey = ls.l_orderkey
WHERE 
    ns.n_name LIKE 'A%'
    AND (ss.total_available > 100 OR ss.total_cost IS NOT NULL)
ORDER BY 
    ns.n_name, ss.s_name, cs.rank DESC;
