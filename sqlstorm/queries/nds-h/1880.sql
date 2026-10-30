
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' 
        AND o.o_orderstatus IN ('O', 'F', 'P')
), 
PartInventory AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_available
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
), 
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        SUM(s.s_acctbal) AS total_acctbal
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
)
SELECT 
    p.p_name,
    pi.total_available,
    sd.total_acctbal,
    COUNT(DISTINCT ro.o_orderkey) AS order_count,
    AVG(ro.o_totalprice) AS avg_order_price,
    MAX(ro.o_orderdate) AS latest_order_date
FROM 
    part p
LEFT JOIN 
    PartInventory pi ON p.p_partkey = pi.ps_partkey
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    RankedOrders ro ON l.l_orderkey = ro.o_orderkey
LEFT JOIN 
    SupplierDetails sd ON l.l_suppkey = sd.s_suppkey
WHERE 
    p.p_size > 10
    AND sd.nation_name IS NOT NULL
GROUP BY 
    p.p_name, pi.total_available, sd.total_acctbal
HAVING 
    COUNT(DISTINCT ro.o_orderkey) > 5
ORDER BY 
    avg_order_price DESC, order_count DESC;
