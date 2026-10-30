
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' 
        AND o.o_orderdate < DATE '1998-01-01'
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        COUNT(ps.ps_partkey) AS part_count,
        SUM(ps.ps_supplycost) AS total_supplycost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
TotalLineItems AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_quantity) AS total_quantity,
        AVG(l.l_discount) AS avg_discount
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate < DATE '1998-10-01'
    GROUP BY 
        l.l_orderkey
),
FinalReport AS (
    SELECT 
        r.r_name,
        COALESCE(ss.part_count, 0) AS supplier_part_count,
        COALESCE(tt.total_quantity, 0) AS total_quantity,
        COALESCE(tt.avg_discount, 0) * 100 AS average_discount_percentage
    FROM 
        region r
    LEFT JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN 
        SupplierStats ss ON ss.s_suppkey = n.n_nationkey
    LEFT JOIN 
        TotalLineItems tt ON tt.l_orderkey = ss.s_suppkey
)
SELECT 
    fr.r_name,
    fr.supplier_part_count,
    fr.total_quantity,
    fr.average_discount_percentage
FROM 
    FinalReport fr
WHERE 
    fr.supplier_part_count > 5 
    OR fr.total_quantity > 1000
ORDER BY 
    fr.r_name ASC,
    fr.total_quantity DESC;
