WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        COUNT(ps.ps_supplycost) AS num_parts,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
),
CustomerOrderDetails AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_order_value,
        AVG(o.o_totalprice) AS avg_order_value,
        COUNT(o.o_orderkey) AS total_orders
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    r.r_name,
    COALESCE(cd.total_order_value, 0) AS total_order_value,
    COALESCE(sd.total_supply_cost, 0) AS total_supplier_cost,
    CASE 
        WHEN COALESCE(cd.total_order_value, 0) > COALESCE(sd.total_supply_cost, 0) THEN 'High Demand'
        ELSE 'Low Demand'
    END AS demand_status,
    ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY COALESCE(cd.total_order_value, 0) DESC) AS rank
FROM 
    region r
LEFT JOIN 
    (SELECT 
         n.n_regionkey, 
         cd.total_order_value, 
         cd.c_custkey
     FROM 
         nation n
     JOIN 
         CustomerOrderDetails cd ON n.n_nationkey = cd.c_custkey) AS cd ON r.r_regionkey = cd.n_regionkey
LEFT JOIN 
    (SELECT 
         s.s_nationkey, 
         SUM(sd.total_supply_cost) AS total_supply_cost 
     FROM 
         SupplierDetails sd 
     JOIN 
         supplier s ON sd.s_suppkey = s.s_suppkey 
     GROUP BY 
         s.s_nationkey) AS sd ON r.r_regionkey = sd.s_nationkey
WHERE 
    (cd.total_order_value IS NOT NULL OR sd.total_supply_cost IS NOT NULL)
ORDER BY 
    r.r_name, rank;
