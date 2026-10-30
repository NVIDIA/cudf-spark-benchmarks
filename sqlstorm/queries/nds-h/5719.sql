WITH RegionStats AS (
    SELECT 
        r.r_name AS region_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        SUM(ps.ps_availqty) AS total_available_quantity,
        AVG(ps.ps_supplycost) AS average_supply_cost
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        r.r_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey AS customer_id,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
TopCustomers AS (
    SELECT 
        customer_id,
        total_spent,
        ROW_NUMBER() OVER (ORDER BY total_spent DESC) AS rank
    FROM 
        CustomerOrders
)
SELECT 
    rs.region_name,
    rs.supplier_count,
    rs.total_available_quantity,
    rs.average_supply_cost,
    tc.customer_id,
    tc.total_spent
FROM 
    RegionStats rs
JOIN 
    TopCustomers tc ON tc.rank <= 10
ORDER BY 
    rs.region_name, tc.total_spent DESC;
