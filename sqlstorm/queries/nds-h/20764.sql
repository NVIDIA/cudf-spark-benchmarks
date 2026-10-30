WITH RankedSuppliers AS (
    SELECT 
        s_name,
        s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s_nationkey ORDER BY s_acctbal DESC) AS rn
    FROM 
        supplier
),
HighValueParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE 
        p.p_retailprice > (SELECT AVG(p_retailprice) FROM part)
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand, p.p_retailprice
),
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        AVG(o.o_totalprice) AS avg_order_value
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
FinalSummary AS (
    SELECT 
        r.r_name,
        ns.n_nationkey,
        SUM(CASE WHEN cs.total_orders > 0 THEN cs.total_spent ELSE 0 END) AS regional_spending,
        AVG(CASE WHEN hs.total_supply_cost > 1000 THEN hs.total_supply_cost ELSE NULL END) AS avg_high_value_supply_cost
    FROM 
        region r
    JOIN 
        nation ns ON r.r_regionkey = ns.n_regionkey
    LEFT JOIN 
        RankedSuppliers rs ON ns.n_nationkey = rs.rn
    FULL OUTER JOIN 
        HighValueParts hs ON hs.p_brand = (
            SELECT p_brand FROM part WHERE p_partkey IN (
                SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_availqty > 500
            ) LIMIT 1
        )
    LEFT JOIN 
        CustomerOrderSummary cs ON ns.n_nationkey = cs.c_custkey % (SELECT COUNT(*) FROM customer)
    WHERE 
        ns.n_nationkey IS NOT NULL
    GROUP BY 
        r.r_name, ns.n_nationkey
)
SELECT 
    r_name,
    n_nationkey,
    regional_spending,
    COALESCE(avg_high_value_supply_cost, 0) AS avg_high_value_supply_cost,
    (CASE WHEN regional_spending > 10000 THEN 'High' WHEN regional_spending BETWEEN 5000 AND 10000 THEN 'Medium' ELSE 'Low' END) AS spending_category
FROM 
    FinalSummary
ORDER BY 
    regional_spending DESC;
