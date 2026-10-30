
WITH SupplyDetails AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_availqty,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        ps.ps_partkey
),
CustomerOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        COUNT(l.l_orderkey) AS line_item_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'F' 
        AND o.o_orderdate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        o.o_orderkey, o.o_custkey
),
CustomerSuppliers AS (
    SELECT 
        c.c_custkey,
        SUM(sd.total_availqty) AS total_supply_quantity,
        SUM(cd.total_order_value) AS total_customer_spending
    FROM 
        CustomerOrders cd
    JOIN 
        customer c ON cd.o_custkey = c.c_custkey
    JOIN 
        SupplyDetails sd ON c.c_custkey = sd.ps_partkey
    GROUP BY 
        c.c_custkey
)
SELECT 
    cs.c_custkey,
    cs.total_supply_quantity,
    cs.total_customer_spending,
    (cs.total_customer_spending / NULLIF(cs.total_supply_quantity, 0)) AS avg_spending_per_supply
FROM 
    CustomerSuppliers cs
WHERE 
    cs.total_supply_quantity > 0
ORDER BY 
    avg_spending_per_supply DESC
LIMIT 50;
