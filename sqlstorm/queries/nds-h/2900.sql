WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_address,
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        COALESCE(SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END), 0) AS total_returns
    FROM 
        customer c
    LEFT JOIN 
        RankedOrders o ON c.c_custkey = o.o_custkey
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.rn = 1 AND o.o_orderdate >= '1997-01-01'
    GROUP BY 
        c.c_custkey, c.c_name, c.c_address, o.o_orderkey, o.o_orderdate, o.o_totalprice
),
HighValueSuppliers AS (
    SELECT 
        ps.ps_partkey,
        p.p_name,
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey, p.p_name, s.s_suppkey, s.s_name
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > 10000
),
FinalReport AS (
    SELECT 
        co.c_name,
        co.o_orderkey,
        co.o_orderdate,
        co.o_totalprice,
        hvs.p_name,
        hvs.total_supply_value,
        CASE 
            WHEN hvs.p_name IS NOT NULL THEN 'Yes' 
            ELSE 'No' 
        END AS high_value_supplier
    FROM 
        CustomerOrders co
    LEFT JOIN 
        HighValueSuppliers hvs ON co.o_orderkey = hvs.ps_partkey
)
SELECT 
    f.c_name,
    f.o_orderkey,
    f.o_orderdate,
    f.o_totalprice,
    f.p_name,
    f.total_supply_value,
    f.high_value_supplier
FROM 
    FinalReport f
WHERE 
    f.o_totalprice > (SELECT AVG(o_totalprice) FROM CustomerOrders WHERE o_totalprice IS NOT NULL)
ORDER BY 
    f.o_orderdate DESC;