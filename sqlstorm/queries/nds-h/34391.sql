WITH  RegionSales AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        r.r_regionkey, r.r_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        SUM(l.l_extendedprice) AS total_order_value
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name, o.o_orderkey
),
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(co.total_order_value) AS total_spent,
        ROW_NUMBER() OVER (ORDER BY SUM(co.total_order_value) DESC) AS rank
    FROM 
        customer c
    JOIN 
        CustomerOrders co ON c.c_custkey = co.c_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(co.total_order_value) > 10000
)
SELECT 
    rs.r_name AS region_name,
    tc.c_name AS customer_name,
    tc.total_spent,
    COALESCE(rs.total_sales, 0) AS total_region_sales
FROM 
    RegionSales rs
RIGHT JOIN 
    TopCustomers tc ON tc.total_spent IS NOT NULL
WHERE 
    tc.rank <= 5
ORDER BY 
    rs.r_name, tc.total_spent DESC;
