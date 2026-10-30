WITH CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
TopCustomers AS (
    SELECT 
        co.c_custkey,
        co.c_name,
        co.total_orders,
        co.total_spent,
        RANK() OVER (ORDER BY co.total_spent DESC) AS rank_order
    FROM 
        CustomerOrders co
)
SELECT 
    p.p_name,
    p.p_brand,
    p.p_retailprice,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
    COALESCE(SUM(l.l_quantity), 0) AS total_quantity,
    r.r_name AS region_name,
    nc.total_orders,
    nc.total_spent
FROM 
    part p
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    TopCustomers nc ON s.s_nationkey = nc.c_custkey
WHERE 
    l.l_shipdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
    AND (p.p_retailprice > 100 OR p.p_container IS NULL)
GROUP BY 
    p.p_name, p.p_brand, p.p_retailprice, r.r_name, nc.total_orders, nc.total_spent
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
ORDER BY 
    total_sales DESC, p.p_name ASC;