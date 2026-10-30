WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name AS customer_name,
        s.s_name AS supplier_name,
        COUNT(l.l_orderkey) AS item_count
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN 
        partsupp ps ON l.l_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1996-01-01' AND DATE '1996-12-31'
        AND l.l_shipdate <= o.o_orderdate
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_totalprice, c.c_name, s.s_name
),
popular_suppliers AS (
    SELECT 
        supplier_name,
        SUM(o.o_totalprice) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM 
        ranked_orders o
    GROUP BY 
        supplier_name
    HAVING 
        SUM(o.o_totalprice) > 100000
)
SELECT 
    r.customer_name,
    ps.supplier_name,
    r.item_count,
    r.o_totalprice,
    r.o_orderdate,
    ps.total_sales,
    ps.total_orders
FROM 
    ranked_orders r
JOIN 
    popular_suppliers ps ON r.supplier_name = ps.supplier_name
ORDER BY 
    ps.total_sales DESC, r.o_orderdate ASC
LIMIT 50;