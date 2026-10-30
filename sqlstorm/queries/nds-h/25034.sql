WITH CustomerPurchases AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name
),
TopCustomers AS (
    SELECT 
        c.*,
        RANK() OVER (ORDER BY total_spent DESC) AS rank
    FROM 
        CustomerPurchases c
)
SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    t.c_name AS customer_name,
    t.total_spent,
    t.total_orders,
    t.last_order_date
FROM 
    TopCustomers t
JOIN 
    supplier s ON s.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (
        SELECT p.p_partkey FROM part p WHERE p.p_brand LIKE 'Brand#1%'
    ) LIMIT 1)
JOIN 
    nation n ON n.n_nationkey = s.s_nationkey
JOIN 
    region r ON r.r_regionkey = n.n_regionkey
WHERE 
    t.rank <= 10
ORDER BY 
    total_spent DESC;
