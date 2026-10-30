
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' 
        AND c.c_acctbal > 1000.00
),
HighValueLineItems AS (
    SELECT 
        l.l_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 5000.00
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_availqty) AS total_avail_qty
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        s.s_acctbal IS NOT NULL 
    GROUP BY 
        s.s_suppkey, s.s_name
),
RegionSummary AS (
    SELECT 
        r.r_name, 
        COUNT(DISTINCT n.n_nationkey) AS nation_count
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY 
        r.r_name
)

SELECT 
    ro.o_orderkey,
    ro.o_orderdate,
    ro.o_totalprice,
    ro.c_name,
    hvl.total_value,
    sd.s_name,
    rs.r_name,
    rs.nation_count
FROM 
    RankedOrders ro
LEFT JOIN 
    HighValueLineItems hvl ON ro.o_orderkey = hvl.l_orderkey
LEFT JOIN 
    SupplierDetails sd ON hvl.l_orderkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_supplycost < 20)
JOIN 
    RegionSummary rs ON ro.o_orderkey % 5 = 0  
WHERE 
    ro.order_rank = 1 
    AND (hvl.total_value IS NOT NULL OR sd.total_avail_qty > 100)
ORDER BY 
    ro.o_totalprice DESC, 
    ro.o_orderdate ASC;
