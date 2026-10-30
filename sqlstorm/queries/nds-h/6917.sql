WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        c.c_acctbal,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_totalprice DESC) AS rn
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1996-01-01' AND DATE '1996-12-31'
),
HighValueParts AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        p.p_retailprice > 100
    GROUP BY 
        ps.ps_partkey
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > 10000
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        n.n_regionkey IN (SELECT r_regionkey FROM region WHERE r_name = 'ASIA')
)
SELECT 
    ro.o_orderkey,
    ro.o_orderdate,
    ro.o_totalprice,
    ro.c_name,
    ro.c_acctbal,
    hvp.total_supply_cost,
    sd.s_suppkey,
    sd.s_name,
    sd.n_name
FROM 
    RankedOrders ro
JOIN 
    HighValueParts hvp ON ro.o_orderkey = hvp.ps_partkey
JOIN 
    SupplierDetails sd ON hvp.ps_partkey = sd.s_suppkey
WHERE 
    ro.rn = 1
ORDER BY 
    ro.o_orderdate DESC, 
    ro.o_totalprice DESC
LIMIT 100;