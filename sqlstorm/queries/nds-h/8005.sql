WITH SupplierParts AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        p.p_partkey,
        p.p_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY ps.ps_supplycost DESC) AS rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
TopSuppliers AS (
    SELECT 
        sp.s_suppkey,
        sp.s_name,
        sp.p_partkey,
        sp.p_name,
        sp.ps_availqty,
        sp.ps_supplycost
    FROM 
        SupplierParts sp
    WHERE 
        sp.rn <= 3
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate
),
FinalAnalytics AS (
    SELECT 
        cs.c_custkey,
        cs.c_name,
        COALESCE(SUM(t.ps_supplycost), 0) AS total_supply_cost,
        COUNT(t.p_partkey) AS total_parts_supplied,
        COALESCE(SUM(co.total_spent), 0) AS customer_spending,
        CASE 
            WHEN COALESCE(SUM(co.total_spent), 0) > 0 THEN 
                (COALESCE(SUM(t.ps_supplycost), 0) / COALESCE(SUM(co.total_spent), 0))
            ELSE 
                0 
        END AS supply_cost_to_spend_ratio
    FROM 
        TopSuppliers t
    LEFT JOIN 
        CustomerOrders co ON t.s_suppkey = co.c_custkey
    LEFT JOIN 
        customer cs ON co.c_custkey = cs.c_custkey
    GROUP BY 
        cs.c_custkey, cs.c_name
)
SELECT 
    fa.c_custkey,
    fa.c_name,
    fa.total_supply_cost,
    fa.total_parts_supplied,
    fa.customer_spending,
    fa.supply_cost_to_spend_ratio
FROM 
    FinalAnalytics fa
ORDER BY 
    fa.supply_cost_to_spend_ratio DESC
LIMIT 10;
