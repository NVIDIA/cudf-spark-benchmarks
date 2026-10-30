
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
),
SupplierCost AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
CustomerSales AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS total_orders
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
)
SELECT 
    p.p_name,
    r.r_name,
    COALESCE(RankedOrders.order_rank, 0) AS order_rank,
    COALESCE(SupplierCost.total_supply_cost, 0) AS total_supply_cost,
    COALESCE(CustomerSales.total_spent, 0) AS total_spent,
    (CASE 
         WHEN CustomerSales.total_orders > 10 THEN 'High Frequency'
         WHEN CustomerSales.total_orders BETWEEN 5 AND 10 THEN 'Medium Frequency'
         ELSE 'Low Frequency'
     END) AS purchase_frequency
FROM 
    part p
LEFT JOIN 
    supplier s ON p.p_partkey = s.s_suppkey
LEFT JOIN 
    region r ON s.s_nationkey = r.r_regionkey
LEFT JOIN 
    RankedOrders ON RankedOrders.o_orderkey = s.s_suppkey
LEFT JOIN 
    SupplierCost ON SupplierCost.ps_partkey = p.p_partkey
LEFT JOIN 
    CustomerSales ON CustomerSales.c_custkey = s.s_nationkey
WHERE 
    r.r_name IS NOT NULL OR (p.p_retailprice > 100 AND p.p_size < 20)
GROUP BY 
    p.p_name,
    r.r_name,
    RankedOrders.order_rank,
    SupplierCost.total_supply_cost,
    CustomerSales.total_spent,
    CustomerSales.total_orders
ORDER BY 
    total_supply_cost DESC, 
    purchase_frequency ASC
LIMIT 100;
