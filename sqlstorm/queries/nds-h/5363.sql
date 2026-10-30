WITH SupplierPerformance AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        COUNT(DISTINCT p.p_partkey) AS part_count,
        AVG(s.s_acctbal) AS average_account_balance
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        s.s_acctbal > 0
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_order_value,
        COUNT(o.o_orderkey) AS total_orders
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O' AND o.o_orderdate >= '1997-01-01'
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    sp.s_name AS supplier_name,
    sp.total_supply_value,
    sp.part_count,
    cos.c_name AS customer_name,
    cos.total_order_value,
    cos.total_orders
FROM 
    SupplierPerformance sp
JOIN 
    CustomerOrderSummary cos ON sp.total_supply_value > 50000 
ORDER BY 
    sp.total_supply_value DESC, cos.total_order_value DESC
LIMIT 10;