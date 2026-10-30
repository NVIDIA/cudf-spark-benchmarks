
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_totalprice, 
        o.o_orderdate,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS status_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND 
        o.o_orderdate < DATE '1997-01-01'
),
SupplierParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        ps.ps_supplycost,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost DESC) AS cost_rank
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE 
        ps.ps_availqty > 0
),
CustomerOrders AS (
    SELECT
        c.c_custkey, 
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 1000
),
FilteredLineItems AS (
    SELECT 
        l.l_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue,
        COUNT(*) FILTER (WHERE l.l_returnflag = 'R') AS returned_items
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate BETWEEN DATE '1996-01-01' AND DATE '1996-12-31'
    GROUP BY 
        l.l_orderkey
)
SELECT 
    r.o_orderkey,
    COALESCE(r.o_totalprice, 0) AS order_total,
    COALESCE(s.p_name, 'Unknown') AS part_name,
    s.ps_supplycost,
    CASE 
        WHEN li.net_revenue IS NULL THEN 'No Sales'
        ELSE 'Sales Present'
    END AS sales_status,
    ROW_NUMBER() OVER (ORDER BY COALESCE(li.net_revenue, 0) DESC) AS sales_rank
FROM 
    RankedOrders r
LEFT JOIN 
    FilteredLineItems li ON r.o_orderkey = li.l_orderkey
FULL OUTER JOIN 
    SupplierParts s ON r.o_orderkey % 10 = s.p_partkey % 10 
LEFT JOIN 
    CustomerOrders co ON r.o_orderkey = co.c_custkey
WHERE 
    r.status_rank <= 5 AND 
    (s.cost_rank IS NULL OR s.cost_rank = 1)
ORDER BY 
    sales_rank, r.o_orderkey;
