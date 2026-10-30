WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        DENSE_RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rank_order
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= '1996-01-01'
),
SupplierDetails AS (
    SELECT 
        ps.ps_partkey,
        s.s_name,
        s.s_acctbal,
        ps.ps_availqty,
        ps.ps_supplycost,
        ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        s.s_acctbal IS NOT NULL AND
        ps.ps_supplycost < (SELECT AVG(ps_supplycost) FROM partsupp)
),
TotalLineItems AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= '1997-01-01'
    GROUP BY 
        l.l_orderkey
)
SELECT 
    r.o_orderkey, 
    r.o_orderstatus, 
    r.o_totalprice,
    COALESCE(td.total_price, 0) AS total_line_item_price,
    COALESCE(sd.s_name, 'Unknown Supplier') AS supplier_name,
    sd.ps_availqty,
    sd.ps_supplycost
FROM 
    RankedOrders r
LEFT JOIN 
    TotalLineItems td ON r.o_orderkey = td.l_orderkey
LEFT JOIN 
    SupplierDetails sd ON sd.ps_partkey = (
        SELECT ps.ps_partkey 
        FROM partsupp ps 
        WHERE ps.ps_partkey IS NOT NULL 
        ORDER BY ps.ps_supplycost 
        LIMIT 1
    ) AND sd.rn = 1
ORDER BY 
    r.o_totalprice DESC,
    r.o_orderdate ASC
LIMIT 100;