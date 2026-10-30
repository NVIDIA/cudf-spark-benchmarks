WITH  total_price AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_total
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
),
supplier_nation AS (
    SELECT 
        s.s_suppkey,
        n.n_name,
        r.r_name AS region_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
),
top_suppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        sn.region_name
    FROM 
        supplier_nation sn
    JOIN 
        supplier s ON sn.s_suppkey = s.s_suppkey
    WHERE 
        sn.rank <= 5
)
SELECT 
    p.p_name,
    COUNT(DISTINCT li.l_orderkey) AS order_count,
    AVG(tp.order_total) AS average_order_value,
    COALESCE(MAX(ts.s_acctbal), 0) AS highest_supplier_acctbal,
    RANK() OVER (ORDER BY AVG(tp.order_total) DESC) AS order_value_rank
FROM 
    part p
LEFT JOIN 
    lineitem li ON p.p_partkey = li.l_partkey
LEFT JOIN 
    total_price tp ON li.l_orderkey = tp.o_orderkey
LEFT JOIN 
    top_suppliers ts ON li.l_suppkey = ts.s_suppkey
GROUP BY 
    p.p_partkey, p.p_name
HAVING 
    COUNT(DISTINCT li.l_orderkey) > 0
ORDER BY 
    average_order_value DESC
LIMIT 10;
