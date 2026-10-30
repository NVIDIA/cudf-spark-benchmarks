WITH RankedSuppliers AS (
    SELECT 
        s_suppkey, 
        s_name, 
        s_nationkey, 
        ROW_NUMBER() OVER (PARTITION BY s_nationkey ORDER BY s_acctbal DESC) as rnk
    FROM 
        supplier
),
CustomerSummary AS (
    SELECT 
        c_custkey, 
        COUNT(o_orderkey) as total_orders, 
        SUM(o_totalprice) as total_spent
    FROM 
        customer
    LEFT JOIN 
        orders ON customer.c_custkey = orders.o_custkey
    GROUP BY 
        c_custkey
),
HighValueOrders AS (
    SELECT 
        o_orderkey, 
        o_custkey, 
        o_totalprice
    FROM 
        orders
    WHERE 
        o_totalprice > (SELECT AVG(o_totalprice) FROM orders)
),
PartSupply AS (
    SELECT 
        ps_partkey, 
        SUM(ps_availqty) as total_available_qty
    FROM 
        partsupp
    GROUP BY 
        ps_partkey
)
SELECT 
    c.c_name AS customer_name,
    cs.total_orders,
    cs.total_spent,
    COUNT(DISTINCT lo.l_orderkey) AS number_of_line_items,
    SUM(lo.l_extendedprice * (1 - lo.l_discount)) AS revenue,
    COALESCE(MAX(s.s_name), 'No Supplier') AS supplier_name,
    COALESCE(MAX(r.r_name), 'Unknown Region') AS region_name
FROM 
    customer c
LEFT JOIN 
    CustomerSummary cs ON c.c_custkey = cs.c_custkey
LEFT JOIN 
    lineitem lo ON c.c_custkey = lo.l_orderkey
LEFT JOIN 
    RankedSuppliers s ON c.c_nationkey = s.s_nationkey AND s.rnk = 1
LEFT JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    cs.total_orders IS NOT NULL OR EXISTS (
        SELECT 1 
        FROM HighValueOrders hvo 
        WHERE hvo.o_custkey = c.c_custkey
    )
GROUP BY 
    c.c_name, cs.total_orders, cs.total_spent
HAVING 
    SUM(lo.l_extendedprice * (1 - lo.l_discount)) > 10000
ORDER BY 
    revenue DESC;
