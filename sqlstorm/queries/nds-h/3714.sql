
WITH SupplierPerformance AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts_supplied
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate >= '1997-01-01' 
        AND l.l_shipdate < '1998-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        COALESCE(SUM(od.total_price), 0) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        OrderDetails od ON c.c_custkey = od.o_orderkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    sp.s_name,
    sp.total_supply_cost,
    COALESCE(co.total_spent, 0) AS total_spent_by_customers,
    COUNT(DISTINCT co.c_custkey) AS number_of_customers,
    ROW_NUMBER() OVER (PARTITION BY sp.s_suppkey ORDER BY sp.total_supply_cost DESC) AS rank
FROM 
    SupplierPerformance sp
LEFT JOIN 
    CustomerOrders co ON sp.s_suppkey = co.c_custkey 
WHERE 
    sp.total_supply_cost > 10000
GROUP BY 
    sp.s_suppkey, 
    sp.s_name, 
    sp.total_supply_cost, 
    co.total_spent
ORDER BY 
    sp.total_supply_cost DESC, number_of_customers ASC;
