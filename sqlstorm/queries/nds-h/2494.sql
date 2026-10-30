WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' 
        AND o.o_orderdate <= DATE '1997-12-31'
), SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty * ps.ps_supplycost) AS total_supply_value
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
), FilteredParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        COUNT(ps.ps_suppkey) AS supplier_count
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE 
        p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
    GROUP BY 
        p.p_partkey, p.p_name, p.p_retailprice
), CustomerSegments AS (
    SELECT 
        c.c_mktsegment,
        COUNT(DISTINCT c.c_custkey) AS cust_count
    FROM 
        customer c
    GROUP BY 
        c.c_mktsegment
)
SELECT 
    o.o_orderkey,
    o.o_orderdate,
    RANK() OVER (ORDER BY o.o_totalprice DESC) AS price_rank,
    COALESCE(pi.total_supply_value, 0) AS supplier_value,
    cs.cust_count,
    fp.p_name,
    fp.p_retailprice
FROM 
    RankedOrders o
LEFT JOIN 
    SupplierInfo pi ON pi.s_suppkey = (
        SELECT ps.ps_suppkey 
        FROM partsupp ps 
        WHERE ps.ps_partkey IN (SELECT fp.p_partkey FROM FilteredParts fp)
        ORDER BY ps.ps_supplycost DESC 
        LIMIT 1
    )
JOIN 
    CustomerSegments cs ON cs.c_mktsegment = 'BUILDING'
LEFT JOIN 
    FilteredParts fp ON fp.p_partkey = (
        SELECT p2.p_partkey 
        FROM FilteredParts p2 
        WHERE p2.supplier_count > 5 
        ORDER BY p2.p_retailprice 
        LIMIT 1
    )
WHERE 
    o.order_rank <= 10
ORDER BY 
    o.o_totalprice DESC, 
    fp.p_retailprice ASC;