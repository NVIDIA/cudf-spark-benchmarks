WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01'
),
SupplierCosts AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        COALESCE(sc.total_supply_cost, 0) AS total_supply_cost
    FROM 
        part p
    LEFT JOIN 
        SupplierCosts sc ON p.p_partkey = sc.ps_partkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    pd.p_name,
    pd.p_retailprice,
    pd.total_supply_cost,
    COALESCE(co.total_orders, 0) AS total_orders,
    COALESCE(co.total_spent, 0) AS total_spent,
    CASE 
        WHEN COALESCE(co.total_orders, 0) > 10 THEN 'High'
        WHEN COALESCE(co.total_orders, 0) BETWEEN 5 AND 10 THEN 'Medium'
        ELSE 'Low'
    END AS order_frequency
FROM 
    PartDetails pd
LEFT JOIN 
    CustomerOrders co ON pd.p_partkey = co.c_custkey
WHERE 
    pd.total_supply_cost > 1000.00
ORDER BY 
    pd.p_retailprice DESC,
    order_frequency ASC;