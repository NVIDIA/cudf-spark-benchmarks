WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        c.c_acctbal,
        ROW_NUMBER() OVER (PARTITION BY c.c_mktsegment ORDER BY o.o_totalprice DESC) AS rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= '1997-01-01'
),
TopSpenders AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.o_totalprice,
        ro.c_name,
        ro.c_acctbal
    FROM 
        RankedOrders ro
    WHERE 
        ro.rank <= 5
),
PartSupplierDetails AS (
    SELECT 
        ps.ps_partkey,
        p.p_name,
        p.p_brand,
        SUM(ps.ps_availqty) AS total_available,
        SUM(ps.ps_supplycost) AS total_cost
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        ps.ps_partkey, p.p_name, p.p_brand
),
OrderLineItems AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        SUM(l.l_quantity) AS total_quantity,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey, l.l_partkey
)
SELECT 
    tso.o_orderkey,
    tso.o_orderdate,
    tso.o_totalprice,
    tso.c_name,
    tsod.total_quantity,
    tsod.total_sales,
    psd.p_name,
    psd.p_brand,
    psd.total_available,
    psd.total_cost
FROM 
    TopSpenders tso
JOIN 
    OrderLineItems tsod ON tso.o_orderkey = tsod.l_orderkey
JOIN 
    PartSupplierDetails psd ON tsod.l_partkey = psd.ps_partkey
WHERE 
    tso.o_totalprice > 1000
ORDER BY 
    tso.o_orderdate DESC, tso.o_totalprice DESC
LIMIT 10;