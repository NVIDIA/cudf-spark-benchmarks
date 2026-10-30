WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        c.c_acctbal,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS rnk
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-12-31'
),
TopOrders AS (
    SELECT 
        r.o_orderkey,
        r.o_orderdate,
        r.o_totalprice,
        r.c_name,
        r.c_acctbal
    FROM 
        RankedOrders r
    WHERE 
        r.rnk <= 5
),
HighValueParts AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_value
    FROM 
        partsupp ps 
    GROUP BY 
        ps.ps_partkey 
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > 1000
),
SupplierDetails AS (
    SELECT
        s.s_name,
        s.s_phone,
        n.n_name AS nation_name,
        COUNT(DISTINCT ps.ps_partkey) AS parts_supplied
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_name, s.s_phone, n.n_name
)
SELECT 
    o.o_orderkey,
    o.o_orderdate,
    o.o_totalprice,
    o.c_name,
    o.c_acctbal,
    p.ps_partkey,
    p.total_value,
    s.s_name,
    s.s_phone,
    s.nation_name,
    s.parts_supplied
FROM 
    TopOrders o
JOIN 
    HighValueParts p ON p.ps_partkey = (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_availqty > 10 ORDER BY ps.ps_supplycost DESC LIMIT 1)
JOIN 
    SupplierDetails s ON s.parts_supplied > 5
ORDER BY 
    o.o_orderdate DESC, o.o_totalprice DESC;