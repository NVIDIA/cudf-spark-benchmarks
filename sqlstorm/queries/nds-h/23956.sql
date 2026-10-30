
WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_retailprice,
        p.p_comment,
        DENSE_RANK() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rank_retailprice
    FROM 
        part p
    WHERE 
        p.p_size BETWEEN 1 AND 20
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        CASE 
            WHEN COUNT(o.o_orderkey) > 10 THEN 'High Value'
            WHEN COUNT(o.o_orderkey) BETWEEN 5 AND 10 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_value
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
SignificantSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    INNER JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > (
            SELECT AVG(total_supply_cost)
            FROM (
                SELECT 
                    SUM(ps2.ps_supplycost * ps2.ps_availqty) AS total_supply_cost
                FROM 
                    supplier s2
                INNER JOIN 
                    partsupp ps2 ON s2.s_suppkey = ps2.ps_suppkey
                GROUP BY 
                    s2.s_suppkey
            ) AS avg_cost
        )
)
SELECT 
    COALESCE(cp.c_name, 'Unknown Customer') AS customer_name,
    cp.total_orders,
    rp.p_name,
    rp.p_retailprice,
    ss.total_supply_cost,
    CASE 
        WHEN cp.total_spent IS NULL THEN 'No Orders'
        ELSE CASE 
            WHEN cp.total_spent > 1000 THEN 'Big Spender'
            ELSE 'Regular Customer'
        END
    END AS spending_category,
    ROW_NUMBER() OVER (PARTITION BY cp.customer_value ORDER BY ss.total_supply_cost DESC) AS rank_supply_cost,
    CASE 
        WHEN rp.rank_retailprice = 1 THEN 'Top Priced Part'
        ELSE 'Other Part'
    END AS part_category
FROM 
    CustomerOrders cp
FULL OUTER JOIN 
    RankedParts rp ON cp.c_custkey = rp.p_partkey
LEFT JOIN 
    SignificantSuppliers ss ON rp.p_partkey = ss.s_suppkey
WHERE 
    (cp.total_orders IS NOT NULL OR ss.total_supply_cost IS NOT NULL) 
    AND (rp.p_retailprice > 50 OR rp.p_brand LIKE 'Brand%')
ORDER BY 
    cp.customer_value, ss.total_supply_cost DESC, rp.p_retailprice DESC;
