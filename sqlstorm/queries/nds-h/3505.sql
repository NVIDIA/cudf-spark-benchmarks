WITH CustomerOrderStats AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count,
        RANK() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS rank
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
SupplierPartStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
RegionNation AS (
    SELECT 
        r.r_regionkey,
        n.n_nationkey,
        n.n_name,
        r.r_name AS region_name
    FROM 
        region r
    INNER JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        cs.total_spent,
        cs.order_count,
        rn.region_name
    FROM 
        CustomerOrderStats cs
    JOIN 
        customer c ON cs.c_custkey = c.c_custkey
    LEFT JOIN 
        RegionNation rn ON c.c_nationkey = rn.n_nationkey
    WHERE 
        cs.rank <= 10
)
SELECT 
    hvc.c_name AS Customer_Name,
    hvc.total_spent AS Total_Spent,
    hvc.order_count AS Order_Count,
    COALESCE(sp.part_count, 0) AS Supplier_Count,
    COALESCE(sp.total_supply_cost, 0) AS Total_Supply_Cost
FROM 
    HighValueCustomers hvc
LEFT JOIN 
    SupplierPartStats sp ON hvc.c_custkey = sp.s_suppkey 
ORDER BY 
    hvc.total_spent DESC;