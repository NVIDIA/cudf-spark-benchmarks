WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rn
    FROM orders o
    WHERE o.o_orderdate >= '1997-01-01'
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE s.s_acctbal > 1000
    GROUP BY s.s_suppkey, s.s_name
),
CriticalParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        COALESCE(ps.ps_availqty, 0) AS available_quantity
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2) 
      AND p.p_size IN (SELECT DISTINCT p_size FROM part WHERE p_container LIKE 'BOX%')
),
OrderLineItems AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_value,
        COUNT(l.l_linenumber) AS line_item_count
    FROM lineitem l
    WHERE l.l_shipdate >= '1997-01-01' 
      AND l.l_returnflag = 'N' 
    GROUP BY l.l_orderkey
)
SELECT 
    ro.o_orderkey,
    ro.o_orderdate,
    ro.o_totalprice,
    sd.s_name AS supplier_name,
    cp.p_name AS critical_part_name,
    cp.available_quantity,
    oli.total_line_value,
    CASE
        WHEN ro.o_orderstatus = 'O' THEN 'Open'
        WHEN ro.o_orderstatus = 'F' THEN 'Finalized'
        ELSE 'Unknown'
    END AS order_status_desc
FROM RankedOrders ro
LEFT JOIN SupplierDetails sd ON sd.part_count > 1
LEFT JOIN CriticalParts cp ON cp.available_quantity > 10
LEFT JOIN OrderLineItems oli ON oli.l_orderkey = ro.o_orderkey
WHERE ro.rn <= 10
ORDER BY ro.o_totalprice DESC, cp.p_name ASC
LIMIT 50;