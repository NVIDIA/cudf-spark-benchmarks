WITH RankedCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        ROW_NUMBER() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > 10000
),
ProductsByRegion AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        COUNT(DISTINCT p.p_partkey) AS product_count,
        AVG(p.p_retailprice) AS avg_retail_price
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
    GROUP BY 
        r.r_regionkey, r.r_name
)
SELECT 
    rc.c_name, 
    rc.total_spent,
    hvs.s_name AS high_value_supplier,
    pbr.r_name,
    pbr.product_count,
    pbr.avg_retail_price
FROM 
    RankedCustomers rc
JOIN 
    HighValueSuppliers hvs ON rc.rank <= 10
JOIN 
    ProductsByRegion pbr ON pbr.product_count > 5
ORDER BY 
    rc.total_spent DESC, 
    hvs.total_supply_cost DESC;
