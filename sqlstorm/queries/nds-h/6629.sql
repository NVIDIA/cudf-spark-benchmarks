WITH RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_mfgr, 
        p.p_brand, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_mfgr, p.p_brand
),
TopParts AS (
    SELECT 
        p_partkey, 
        p_name, 
        p_mfgr, 
        p_brand, 
        total_supply_cost,
        ROW_NUMBER() OVER (ORDER BY total_supply_cost DESC) AS rn
    FROM 
        RankedParts
),
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(o.o_totalprice) AS total_orders_value
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
RankedCustomers AS (
    SELECT 
        c_custkey, 
        c_name, 
        total_orders_value,
        DENSE_RANK() OVER (ORDER BY total_orders_value DESC) AS customer_rank
    FROM 
        CustomerOrders
)
SELECT 
    tp.p_partkey, 
    tp.p_name, 
    tp.total_supply_cost, 
    rc.c_custkey, 
    rc.c_name, 
    rc.total_orders_value
FROM 
    TopParts tp
JOIN 
    RankedCustomers rc ON rc.customer_rank <= 5
WHERE 
    tp.total_supply_cost > 10000
ORDER BY 
    tp.total_supply_cost DESC, rc.total_orders_value DESC;
