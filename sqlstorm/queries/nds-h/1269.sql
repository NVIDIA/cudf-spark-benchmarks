WITH SupplierCosts AS (
    SELECT 
        ps.ps_partkey,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey, s.s_nationkey
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        COALESCE(SC.total_supply_cost, 0) AS total_supply_cost
    FROM 
        part p
    LEFT JOIN 
        SupplierCosts SC ON p.p_partkey = SC.ps_partkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        c.c_custkey
)
SELECT 
    PD.p_name,
    PD.p_brand,
    PD.p_retailprice,
    PD.total_supply_cost,
    COALESCE(CO.order_count, 0) AS order_count,
    COALESCE(CO.total_spent, 0) AS total_spent,
    CASE 
        WHEN COALESCE(CO.total_spent, 0) > 10000 THEN 'High Spender'
        WHEN COALESCE(CO.total_spent, 0) BETWEEN 5000 AND 10000 THEN 'Medium Spender'
        ELSE 'Low Spender'
    END AS spender_category
FROM 
    PartDetails PD
LEFT JOIN 
    CustomerOrders CO ON PD.p_partkey = CO.c_custkey
WHERE 
    PD.total_supply_cost > (
        SELECT AVG(total_supply_cost) FROM SupplierCosts
    )
ORDER BY 
    PD.p_retailprice DESC, COALESCE(CO.total_spent, 0) DESC;
