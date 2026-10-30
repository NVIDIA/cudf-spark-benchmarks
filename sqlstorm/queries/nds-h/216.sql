
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank,
        o.o_orderstatus
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
), 
PartSupplier AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_available_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps 
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
)
SELECT 
    p.p_name,
    n.n_name,
    COALESCE(SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_extendedprice * (1 - l.l_discount) END), 0) AS total_returns,
    COALESCE(SUM(l.l_extendedprice), 0) AS total_sales,
    ROUND(AVG(CASE WHEN l.l_linenumber = 1 THEN l.l_extendedprice END), 2) AS avg_first_line_item_price,
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    CASE 
        WHEN COUNT(DISTINCT CASE WHEN o.o_orderstatus = 'O' THEN o.o_orderkey END) > 0 THEN 'Active Orders' 
        ELSE 'No Active Orders' 
    END AS order_status
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
INNER JOIN 
    lineitem l ON l.l_partkey = p.p_partkey
LEFT JOIN 
    RankedOrders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON c.c_custkey = o.o_orderkey
WHERE 
    p.p_retailprice > 0 
    AND p.p_size BETWEEN 1 AND 25
    AND (n.n_regionkey IS NULL OR n.n_regionkey = 1)
GROUP BY 
    p.p_partkey, p.p_name, n.n_name
HAVING 
    AVG(ps.ps_supplycost) > (
        SELECT AVG(ps2.ps_supplycost)
        FROM partsupp ps2
        WHERE ps2.ps_partkey = p.p_partkey
    )
ORDER BY 
    total_sales DESC, 
    total_returns ASC
LIMIT 100;
