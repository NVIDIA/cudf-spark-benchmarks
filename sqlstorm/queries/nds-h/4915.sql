WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available,
        SUM(ps.ps_supplycost) AS total_cost,
        AVG(s.s_acctbal) AS avg_acct_balance,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_availqty) DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
OrderStats AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        COUNT(l.l_orderkey) AS total_line_items,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        MAX(CASE WHEN l.l_returnflag = 'R' THEN 1 ELSE 0 END) AS return_indicator
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
    GROUP BY 
        o.o_orderkey, o.o_custkey
)
SELECT 
    coalesce(n.n_name, 'Unknown') AS nation_name,
    s.s_name AS supplier_name,
    os.total_revenue,
    os.total_line_items,
    ss.total_available,
    ss.avg_acct_balance,
    CASE 
        WHEN os.return_indicator = 1 THEN 'Returned' 
        ELSE 'Not Returned' 
    END AS order_return_status,
    'Region: ' || coalesce(r.r_name, 'N/A') || ', Product: ' || SUM(ps.ps_supplycost) AS product_details
FROM 
    nation n
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    SupplierStats ss ON ss.s_suppkey = s.s_suppkey
LEFT JOIN 
    OrderStats os ON s.s_suppkey = os.o_custkey
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
WHERE 
    (ss.total_available IS NOT NULL OR os.total_revenue > 1000) 
    AND ss.supplier_rank <= 3
GROUP BY 
    n.n_name, s.s_name, os.total_revenue, os.total_line_items, ss.total_available, 
    ss.avg_acct_balance, os.return_indicator, r.r_name
ORDER BY 
    total_revenue DESC
LIMIT 100;