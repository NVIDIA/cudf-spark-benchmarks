
WITH regional_stats AS (
    SELECT 
        r.r_name AS region_name,
        COUNT(DISTINCT n.n_nationkey) AS nation_count,
        SUM(s.s_acctbal) AS total_supplier_balance,
        AVG(s.s_acctbal) AS avg_supplier_balance
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        r.r_name
),
order_summary AS (
    SELECT 
        o.o_orderkey,
        c.c_name AS customer_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        COUNT(l.l_orderkey) AS item_count,
        DENSE_RANK() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'F'
    GROUP BY 
        o.o_orderkey, c.c_name, c.c_nationkey
),
discounted_items AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * l.l_discount) AS total_discount
    FROM 
        lineitem l
    WHERE 
        l.l_discount > 0.05
    GROUP BY 
        l.l_orderkey
)
SELECT 
    rs.region_name,
    os.customer_name,
    os.total_order_value,
    os.item_count,
    di.total_discount,
    CASE 
        WHEN di.total_discount IS NULL THEN 'No Discount'
        ELSE 'Discount Applied'
    END AS discount_status
FROM 
    regional_stats rs
LEFT JOIN 
    order_summary os ON rs.nation_count > 1
LEFT JOIN 
    discounted_items di ON os.o_orderkey = di.l_orderkey
WHERE 
    rs.total_supplier_balance IS NOT NULL
    AND os.order_rank <= 5
ORDER BY 
    rs.region_name, os.total_order_value DESC;
