WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
), SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        r.r_name AS region_name
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
), PartSuppliers AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        ps.ps_availqty,
        ps.ps_supplycost,
        ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY ps.ps_supplycost) AS cost_rank
    FROM 
        partsupp ps
), HighValueOrders AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.o_totalprice,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS extended_price
    FROM 
        RankedOrders ro
    JOIN 
        lineitem l ON ro.o_orderkey = l.l_orderkey
    GROUP BY 
        ro.o_orderkey, ro.o_orderdate, ro.o_totalprice
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
)
SELECT 
    hvo.o_orderkey,
    hvo.o_orderdate,
    hvo.o_totalprice,
    COALESCE(ps.ps_availqty, 0) AS available_quantity,
    COALESCE(sd.s_acctbal, 0) AS supplier_account_balance,
    sd.region_name,
    COUNT(distinct sd.s_suppkey) AS supplier_count
FROM 
    HighValueOrders hvo
LEFT JOIN 
    PartSuppliers ps ON hvo.o_orderkey = ps.ps_partkey 
LEFT JOIN 
    SupplierDetails sd ON ps.ps_suppkey = sd.s_suppkey
WHERE 
    hvo.o_orderdate >= '1997-01-01' 
    AND sd.region_name IS NOT NULL
GROUP BY 
    hvo.o_orderkey, hvo.o_orderdate, hvo.o_totalprice, ps.ps_availqty, sd.s_acctbal, sd.region_name
ORDER BY 
    hvo.o_orderdate DESC, hvo.o_totalprice DESC;