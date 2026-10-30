WITH  customer_orders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'
), 
region_stats AS (
    SELECT 
        r.r_name,
        COUNT(DISTINCT n.n_nationkey) AS num_nations,
        SUM(s.s_acctbal) AS total_supplier_balance,
        AVG(s.s_acctbal) AS avg_supplier_balance
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        r.r_name
), 
lineitem_summary AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(l.l_linenumber) AS total_items,
        MIN(l.l_shipdate) AS earliest_ship_date
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
)
SELECT 
    c.c_name AS customer_name,
    co.o_orderkey,
    co.o_orderdate,
    rs.r_name AS region_name,
    ls.total_revenue,
    ls.total_items,
    CASE 
        WHEN ls.total_revenue > 1000 THEN 'High Value'
        ELSE 'Low Value'
    END AS order_value_category,
    CASE 
        WHEN co.o_orderdate IS NULL THEN 'NO ORDERS'
        ELSE 'HAVE ORDERS'
    END AS order_status,
    COALESCE(rs.total_supplier_balance, 0) AS supplier_balance
FROM 
    customer_orders co
JOIN 
    customer c ON co.c_custkey = c.c_custkey
LEFT JOIN 
    region_stats rs ON rs.num_nations > 1
LEFT JOIN 
    lineitem_summary ls ON co.o_orderkey = ls.l_orderkey
WHERE 
    (co.rn = 1 OR ls.total_items > 5)
ORDER BY 
    c.c_name ASC, 
    co.o_orderdate DESC;
