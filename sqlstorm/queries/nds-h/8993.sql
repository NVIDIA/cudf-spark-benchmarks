WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
RankedSuppliers AS (
    SELECT 
        ss.*,
        ROW_NUMBER() OVER (ORDER BY ss.total_supply_cost DESC) AS rank_by_cost
    FROM 
        SupplierStats ss
),
RankedCustomers AS (
    SELECT 
        co.*,
        ROW_NUMBER() OVER (ORDER BY co.total_spent DESC) AS rank_by_spending
    FROM 
        CustomerOrders co
)
SELECT 
    rs.s_name AS Supplier_Name,
    rs.total_supply_cost,
    rc.c_name AS Customer_Name,
    rc.total_spent
FROM 
    RankedSuppliers rs
INNER JOIN 
    RankedCustomers rc ON rs.total_parts > 5 AND rc.total_orders > 5
WHERE 
    rs.rank_by_cost <= 10 AND rc.rank_by_spending <= 10
ORDER BY 
    rs.total_supply_cost DESC, rc.total_spent DESC;
