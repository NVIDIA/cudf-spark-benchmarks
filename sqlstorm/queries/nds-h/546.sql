WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        n.n_name AS nation_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal, n.n_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        MAX(o.o_orderdate) AS last_order_date,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
)
SELECT 
    sd.s_name,
    sd.nation_name,
    sd.total_supply_cost,
    co.total_orders,
    co.total_spent,
    CASE 
        WHEN co.total_orders > 10 THEN 'Frequent Buyer' 
        WHEN co.total_orders BETWEEN 1 AND 10 THEN 'Occasional Buyer' 
        ELSE 'No Orders' 
    END AS buying_category,
    ROW_NUMBER() OVER (PARTITION BY sd.nation_name ORDER BY sd.total_supply_cost DESC) AS rn
FROM 
    SupplierDetails sd
FULL OUTER JOIN 
    CustomerOrders co ON sd.s_suppkey = co.c_custkey
WHERE 
    (sd.total_supply_cost IS NOT NULL OR co.total_spent IS NOT NULL)
    AND (sd.total_supply_cost > 1000 OR co.total_spent > 500)
ORDER BY 
    sd.nation_name, rn
LIMIT 100;
