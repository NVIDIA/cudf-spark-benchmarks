
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS price_rank,
        COUNT(DISTINCT l.l_linenumber) AS lineitem_count
    FROM 
        orders o
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_totalprice, o.o_orderstatus
),
SelectedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        CASE WHEN COUNT(ps.ps_partkey) > 0 THEN 'Active' ELSE 'Inactive' END AS supplier_status
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        s.s_acctbal IS NOT NULL AND 
        s.s_comment LIKE '%reliable%'
    GROUP BY 
        s.s_suppkey, s.s_name
)
SELECT 
    r.o_orderkey,
    r.o_orderdate,
    r.o_totalprice,
    COALESCE(s.total_supply_cost, 0) AS total_supply_cost,
    r.lineitem_count,
    s.supplier_status,
    CASE 
        WHEN r.price_rank = 1 THEN 'Top Price' 
        WHEN r.price_rank IS NULL THEN 'No Price' 
        ELSE 'Regular Price' 
    END AS price_classification
FROM 
    RankedOrders r
FULL OUTER JOIN 
    SelectedSuppliers s ON r.o_orderkey = s.s_suppkey
WHERE 
    (r.lineitem_count > 2 OR s.supplier_status = 'Active') AND
    (s.total_supply_cost >= 1000 OR s.total_supply_cost IS NULL)
ORDER BY 
    r.o_orderdate DESC, s.total_supply_cost DESC
LIMIT 10;
