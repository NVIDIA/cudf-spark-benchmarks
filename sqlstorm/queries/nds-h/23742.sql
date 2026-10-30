WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY c.c_mktsegment ORDER BY o.o_totalprice DESC) AS rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
),
SupplierPartInfo AS (
    SELECT 
        s.s_suppkey,
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_available_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, ps.ps_partkey
),
HighValueParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        COALESCE(MAX(s.total_available_qty), 0) AS max_available_qty
    FROM 
        part p
    LEFT JOIN 
        SupplierPartInfo s ON p.p_partkey = s.ps_partkey
    WHERE 
        p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
    GROUP BY 
        p.p_partkey, p.p_name, p.p_retailprice
),
FilteredOrders AS (
    SELECT 
        r.o_orderkey,
        r.o_orderdate,
        r.o_totalprice,
        COALESCE(hvp.max_available_qty, 0) AS max_available_qty
    FROM 
        RankedOrders r
    LEFT JOIN 
        HighValueParts hvp ON r.o_orderkey % 10 = hvp.p_partkey % 10
    WHERE 
        r.rank <= 5
)
SELECT 
    f.o_orderkey,
    f.o_orderdate,
    f.o_totalprice,
    SUM(CASE 
        WHEN f.max_available_qty IS NULL THEN 0 
        ELSE f.max_available_qty 
    END) AS total_avail_qty,
    COUNT(*) FILTER (WHERE f.o_totalprice > 1000) AS high_value_count
FROM 
    FilteredOrders f
WHERE 
    f.o_orderdate IS NOT NULL
GROUP BY 
    f.o_orderkey, f.o_orderdate, f.o_totalprice
HAVING 
    SUM(f.max_available_qty) > 0
ORDER BY 
    f.o_orderdate DESC, f.o_orderkey ASC;