WITH RegionalSales AS (
    SELECT 
        r.r_name AS region,
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
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        r.r_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.total_spent
    FROM 
        CustomerOrders c
    WHERE 
        c.total_spent > (
            SELECT 
                AVG(total_spent) 
            FROM 
                CustomerOrders
        )
)
SELECT 
    rs.region,
    tc.c_name,
    tc.total_spent,
    rs.total_sales,
    (tc.total_spent / rs.total_sales) * 100 AS contribution_percentage
FROM 
    RegionalSales rs
JOIN 
    TopCustomers tc ON rs.total_sales > 0
ORDER BY 
    rs.region, contribution_percentage DESC;
